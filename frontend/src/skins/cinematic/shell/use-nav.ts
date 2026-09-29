"use client";
import { usePathname } from "next/navigation";
import { useEffect, useMemo } from "react";
import { useFollowedIndex } from "@/features/library/hooks";
import { litItemFor, resolveNav, type Resolved } from "./nav-map";
import { useShellState } from "./shell-state";

/** Whether a feature or book route names a followed series (the cold-load rule: Library when followed, else Discover). */
export function isFollowedRoute(pathname: string, index: ReadonlyMap<string, number>): boolean {
  const s = pathname.split("?")[0].split("/").filter(Boolean);
  if (s[0] === "library") return true;
  if (s[0] === "sources" && s[2] === "series" && s[3]) {
    try { return index.has(`${decodeURIComponent(s[1])}:${decodeURIComponent(s[3])}`); } catch { return false; }
  }
  return false;
}

/** The lit item and breadcrumb for the current route, keeping the held item across feature pages. Also records the held item. */
export function useNav(): Resolved {
  const pathname = usePathname() ?? "/";
  const held = useShellState((s) => s.held);
  const setHeld = useShellState((s) => s.setHeld);
  const { index } = useFollowedIndex();
  useEffect(() => { const l = litItemFor(pathname); if (l && l !== useShellState.getState().held) setHeld(l); }, [pathname, setHeld]);
  return useMemo(() => resolveNav(pathname, { held, followed: isFollowedRoute(pathname, index) }), [pathname, held, index]);
}
