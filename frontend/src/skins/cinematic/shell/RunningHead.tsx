"use client";
import { usePathname } from "next/navigation";
import { useEffect, useState } from "react";
import { useCurrentUser } from "@/features/auth/hooks";
import { useOnlineStatus } from "@/features/offline/hooks";
import { useUnreadNotificationCount } from "@/features/updates/hooks";
import { Button } from "../primitives/Button";
import { ContentModeChip } from "../primitives/ContentModeChip";
import { Sheet } from "../primitives/Sheet";
import { durMs } from "../tokens.generated";
import { AccountMenu, useSignOut } from "./AccountMenu";
import { RunningHeadView, type Crumb, type OfflineBadge } from "./RunningHeadView";
import { useRunningHeadStore } from "./running-head-context";
import { useShellState } from "./shell-state";
import { navItem, type NavItemId } from "./nav-map";
import { useCineRouter } from "./use-cine-router";
import { useNav } from "./use-nav";

/** Offline edition (§7.13): the badge for 4000 ms after the change, then a glyph; BACK ONLINE for 2000 ms. */
export function useOfflineBadge(offline: boolean): OfflineBadge {
  const [state, setState] = useState<OfflineBadge>("none");
  const [prev, setPrev] = useState(false);
  if (prev !== offline) {
    setPrev(offline);
    setState(offline ? "edition" : prev ? "back-online" : "none");
  }
  useEffect(() => {
    if (state === "edition") { const t = setTimeout(() => setState("glyph"), durMs.holdEdition); return () => clearTimeout(t); }
    if (state === "back-online") { const t = setTimeout(() => setState("none"), durMs.holdBrief); return () => clearTimeout(t); }
  }, [state]);
  return state;
}

/** Scroll thresholds: 24 px on the phone, 80 px on the desktop frame. Only read in the scroll handler, so hydration stays stable. */
function useSolid(): boolean {
  const [solid, setSolid] = useState(false);
  useEffect(() => {
    const on = () => setSolid(window.scrollY > (window.matchMedia("(min-width: 768px)").matches ? 80 : 24));
    on();
    window.addEventListener("scroll", on, { passive: true });
    return () => window.removeEventListener("scroll", on);
  }, []);
  return solid;
}

/** True while the page masthead h1 is on screen (the phone title cross-fades in once it scrolls under the bar). */
function useMastheadVisible(pathname: string): boolean {
  const [visible, setVisible] = useState(true);
  useEffect(() => {
    let io: IntersectionObserver | null = null;
    let raf = 0, tries = 0;
    const find = () => {
      const h1 = document.querySelector("main h1");
      if (!h1) { if (tries++ < 30) raf = requestAnimationFrame(find); return; }
      io = new IntersectionObserver(([e]) => setVisible(e.isIntersecting), { rootMargin: "-44px 0px 0px 0px" });
      io.observe(h1);
    };
    setVisible(true); // eslint-disable-line react-hooks/set-state-in-effect -- reset per route
    find();
    return () => { cancelAnimationFrame(raf); io?.disconnect(); };
  }, [pathname]);
  return visible;
}

/** The running head with its data (§7.13). */
export function RunningHead() {
  const pathname = usePathname() ?? "/";
  const cfg = useRunningHeadStore((s) => s.cfg);
  const nav = useNav();
  const router = useCineRouter();
  const { data: user } = useCurrentUser();
  const { data: unread } = useUnreadNotificationCount();
  const online = useOnlineStatus();
  const unreachable = useShellState((s) => s.unreachable);
  const badge = useOfflineBadge(!online || unreachable);
  const setPalette = useShellState((s) => s.setPaletteOpen);
  const signOut = useSignOut();
  const solid = useSolid();
  const mastheadVisible = useMastheadVisible(pathname);
  const [sheet, setSheet] = useState(false);
  const item = nav.lit && nav.lit in ITEM_IDS ? navItem(nav.lit as NavItemId) : null;
  const crumb: Crumb = item
    ? { folio: item.folio, section: item.label.toUpperCase(), sectionHref: item.href, tail: nav.dynamicTail ? cfg.breadcrumbTail : nav.tail }
    : { section: nav.crumb, tail: nav.tail ?? cfg.breadcrumbTail };
  return (
    <>
      <RunningHeadView crumb={crumb} title={cfg.title ?? crumb.section} back={cfg.back} onBack={() => router.back()} trailing={cfg.trailing}
        contentModeChip={cfg.contentModeChip ? <ContentModeChip /> : undefined} overArt={cfg.overArt} solid={solid} titleVisible={!mastheadVisible}
        unread={unread?.count ?? 0} offline={badge} onSearch={() => setPalette(true)} onBell={() => router.push("/updates", "section")}
        onOfflineGlyph={() => setSheet(true)} account={<AccountMenu user={user} signOut={signOut} />} />
      <Sheet open={sheet} onOpenChange={setSheet} title="The server isn't reachable" kicker="OFFLINE EDITION">
        <p className="type-body text-ink-60">The server isn&apos;t reachable right now. Chapters you saved still open on this device.</p>
        <div className="mt-4"><Button variant="primary" onClick={() => { setSheet(false); router.push("/downloads", "section"); }}>Go to Downloads</Button></div>
      </Sheet>
    </>
  );
}

const ITEM_IDS: Record<string, true> = { tonight: true, library: true, updates: true, discover: true, downloads: true, collections: true, history: true, bookmarks: true, dialogue: true, numbers: true, circle: true, picks: true };
