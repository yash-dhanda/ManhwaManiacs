"use client";
import { usePathname } from "next/navigation";
import { useOfflineState } from "@/features/offline/hooks";
import { useUnreadNotificationCount } from "@/features/updates/hooks";
import { haptic } from "../haptics";
import { downloadsBadge } from "./badges";
import { BRANCH_ROOTS, thumbFor, type Branch } from "./nav-map";
import { ThumbIndexView } from "./ThumbIndexView";
import { useCineRouter } from "./use-cine-router";
import { readReduced } from "../motion";

const LONG: Partial<Record<Branch, string>> = { library: "/updates", downloads: "/downloads#queue", index: "/profiles?switch=1" };

/** The thumb index with its behaviour (§7.14): tap-active scroll/root/search, long-press shortcuts, badges. */
export function ThumbIndex() {
  const pathname = usePathname() ?? "/";
  const { visible, active } = thumbFor(pathname);
  const router = useCineRouter();
  const { data: unread } = useUnreadNotificationCount();
  const offline = useOfflineState();
  if (!visible) return null;
  const onTab = (id: Branch, e: React.MouseEvent) => {
    if (id !== active) return; // a plain section change: the link navigates with nav="section"
    e.preventDefault();
    const atTop = window.scrollY < 8;
    const atRoot = pathname === BRANCH_ROOTS[id];
    if (!atTop) { window.scrollTo({ top: 0, behavior: readReduced() ? "auto" : "smooth" }); return; }
    if (!atRoot) { router.push(BRANCH_ROOTS[id], "section"); return; }
    if (id === "discover") window.dispatchEvent(new CustomEvent("mm:focus-search"));
  };
  return (
    <ThumbIndexView active={active} badges={{ library: unread?.count ?? 0, downloads: downloadsBadge(offline) }} onTab={onTab}
      onLongPress={(id) => { const to = LONG[id]; if (to) { haptic("longpress.open"); router.push(to, "section"); } }} />
  );
}
