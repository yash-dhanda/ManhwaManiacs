"use client";
import { usePathname } from "next/navigation";
import { useCallback, useEffect, useMemo, useState, useSyncExternalStore } from "react";
import { useOfflineState } from "@/features/offline/hooks";
import { useServerCapabilities } from "@/features/preferences/hooks";
import { useUnreadNotificationCount } from "@/features/updates/hooks";
import { useCurrentUser } from "@/features/auth/hooks";
import { useContentMode } from "@/features/content-mode/use-content-mode";
import { SidebarView } from "./SidebarView";
import type { NavItemId } from "./nav-map";
import { useNav } from "./use-nav";
import { useShellState } from "./shell-state";
import { downloadsBadge } from "./badges";

const KEY = "mm.sidebar";
const subscribe = (q: string) => (cb: () => void) => { const m = window.matchMedia(q); m.addEventListener("change", cb); return () => m.removeEventListener("change", cb); };
export const useMinWidth = (px: number) => useSyncExternalStore(subscribe(`(min-width: ${px}px)`), () => window.matchMedia(`(min-width: ${px}px)`).matches, () => false);

function readStored(): "expanded" | "spine" {
  try { return localStorage.getItem(KEY) === "spine" ? "spine" : "expanded"; } catch { return "expanded"; }
}

/** The sidebar mode and its toggle (§7.15): auto-spine 768-1279; from 1280 the stored choice; below 1280 the toggle opens the overlay. */
export function useSidebar() {
  const wide = useMinWidth(1280);
  const overlay = useShellState((s) => s.sidebarOverlay);
  const setOverlay = useShellState((s) => s.setSidebarOverlay);
  const [stored, setStored] = useState<"expanded" | "spine">("expanded");
  useEffect(() => { setStored(readStored()); }, []); // eslint-disable-line react-hooks/set-state-in-effect -- per-device value read after hydration
  const spine = wide ? stored === "spine" : true;
  const toggle = useCallback(() => {
    if (wide) {
      const next = stored === "spine" ? "expanded" : "spine";
      setStored(next);
      try { localStorage.setItem(KEY, next); } catch { /* private mode */ }
    } else setOverlay(!useShellState.getState().sidebarOverlay);
  }, [wide, stored, setOverlay]);
  return { wide, spine, stored, overlay, setOverlay, toggle };
}

/** The Contents sidebar with its data (§7.15). */
export function Sidebar({ sidebar, wordmarkRef }: { sidebar: ReturnType<typeof useSidebar>; wordmarkRef?: React.Ref<HTMLSpanElement> }) {
  const pathname = usePathname();
  const { data: user } = useCurrentUser();
  const { data: unread } = useUnreadNotificationCount();
  const offline = useOfflineState();
  const caps = useServerCapabilities();
  const { mode, novelsEnabled } = useContentMode();
  const { lit } = useNav();
  const hidden = useMemo(() => {
    const h = new Set<NavItemId>();
    if (!caps.client_downloads) h.add("downloads");
    if (!caps.ocr || (novelsEnabled && mode === "novel")) h.add("dialogue");
    if (!caps.collections) h.add("collections");
    if (!caps.bookmarks) h.add("bookmarks");
    return h;
  }, [caps, mode, novelsEnabled]);
  const counts = { updates: unread?.count ?? 0, downloads: downloadsBadge(offline) };
  const { spine, overlay, setOverlay, toggle } = sidebar;
  // Close the overlay on navigation.
  useEffect(() => { setOverlay(false); }, [pathname, setOverlay]);
  useEffect(() => {
    if (!overlay) return;
    const esc = (e: KeyboardEvent) => { if (e.key === "Escape") setOverlay(false); };
    window.addEventListener("keydown", esc);
    return () => window.removeEventListener("keydown", esc);
  }, [overlay, setOverlay]);
  return (
    <>
      <SidebarView spine={spine} lit={lit} counts={counts} isAdmin={Boolean(user?.is_admin)} novelsEnabled={novelsEnabled} hidden={hidden} onToggle={toggle} wordmarkRef={wordmarkRef} />
      {overlay ? (
        <>
          <div data-sidebar-scrim onClick={() => setOverlay(false)} style={{ position: "fixed", inset: 0, zIndex: "calc(var(--mm-z-panel) - 1)", background: "var(--mm-scrim-modal)" }} />
          <SidebarView spine={false} overlay lit={lit} counts={counts} isAdmin={Boolean(user?.is_admin)} novelsEnabled={novelsEnabled} hidden={hidden} onToggle={() => setOverlay(false)} onNavigate={() => setOverlay(false)} />
        </>
      ) : null}
    </>
  );
}
