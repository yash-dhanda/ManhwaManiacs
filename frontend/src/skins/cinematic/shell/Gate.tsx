"use client";
import { usePathname } from "next/navigation";
import { useEffect, useRef } from "react";
import { isPublicAuthPath } from "@/features/auth/access";
import { useCurrentUser } from "@/features/auth/hooks";
import { isSessionUnresolved, resolveSessionGate, type SessionGate } from "@/features/offline/session-gate";
import { PROFILE_PICKER_PATH, shouldRedirectToPicker } from "@/features/profiles/access";
import { useProfiles } from "@/features/profiles/hooks";
import { isSelectionGone } from "@/features/profiles/selection";
import { useActiveProfileStore } from "@/features/profiles/store";
import { dip } from "./Overlays";
import { frameFor } from "./frames";
import { useShellState } from "./shell-state";
import { useCineRouter } from "./use-cine-router";

/** Drops the remembered profile once this account's own list shows it is gone; the gate then sends the user to the picker. */
export function StaleProfileCheck() {
  const activeId = useActiveProfileStore((s) => s.activeProfile?.id ?? null);
  const clear = useActiveProfileStore((s) => s.clearActiveProfile);
  const { data: profiles, isSuccess, isFetching } = useProfiles();
  const gone = isSelectionGone(activeId, { profiles, isSuccess, isFetching });
  useEffect(() => { if (gone) clear(); }, [gone, clear]);
  return null;
}

/**
 * Session and profile guards (G2-G7), the same logic as the legacy `AuthenticatedShell`:
 * signed out -> /login with a Dip; signed in without a profile -> /profiles with a Dip; a stale remembered profile is cleared;
 * a probe that never reached the server does not redirect. `unresolved` holds the splash. The 401 and `profile_required` handlers in
 * `app/providers.tsx` stay the source of truth; this reacts to their state.
 */
export function useGate(): { unresolved: boolean; gate: SessionGate | "public" } {
  const pathname = usePathname() ?? "/";
  const router = useCineRouter();
  const frame = frameFor(pathname);
  const isPublic = frame === "bare" || isPublicAuthPath(pathname);
  const { data: user, isLoading, error } = useCurrentUser();
  const activeProfile = useActiveProfileStore((s) => s.activeProfile);
  const hydrated = useActiveProfileStore((s) => s.hasHydrated);
  const setUnreachable = useShellState((s) => s.setUnreachable);
  const gate = resolveSessionGate({ isLoading, hasUser: Boolean(user), error });
  const busy = useRef<string | null>(null);

  useEffect(() => { setUnreachable(!isPublic && gate === "admit-offline"); }, [gate, isPublic, setUnreachable]);

  useEffect(() => {
    if (isPublic) return;
    let target: string | null = null;
    if (gate === "redirect") target = "/login";
    else if (!isSessionUnresolved(gate) && shouldRedirectToPicker({ authenticated: true, hydrated, hasActiveProfile: Boolean(activeProfile), pathname })) target = PROFILE_PICKER_PATH;
    if (!target) { busy.current = null; return; }
    if (busy.current === target) return;
    busy.current = target;
    void dip(() => router.replace(target!, "forward"));
  }, [gate, isPublic, hydrated, activeProfile, pathname, router]);

  return { unresolved: !isPublic && isSessionUnresolved(gate), gate: isPublic ? "public" : gate };
}
