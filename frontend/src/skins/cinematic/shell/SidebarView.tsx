"use client";
import { SidebarSimpleIcon } from "@phosphor-icons/react/ssr";
import { Wordmark } from "../brand/Wordmark";
import { ContentModeToggle } from "../primitives/ContentModeToggle";
import { Glyph } from "../primitives/glyphs";
import { Menu } from "../primitives/Menu";
import { OxfordRule } from "../primitives/OxfordRule";
import { Tooltip } from "../primitives/Tooltip";
import { Monogram } from "../brand/Monogram";
import { CineLink } from "./CineLink";
import { NAV_ITEMS, type FooterItemId, type Lit, type NavItem, type NavItemId } from "./nav-map";

export type SidebarViewProps = {
  spine: boolean;
  /** The 248 px overlay below 1280 (z.panel over a scrim). */
  overlay?: boolean;
  lit: Lit;
  counts: Partial<Record<NavItemId | FooterItemId, number>>;
  isAdmin: boolean;
  novelsEnabled: boolean;
  /** Capabilities from the server hide items it does not offer. */
  hidden: ReadonlySet<NavItemId>;
  onToggle: () => void;
  onNavigate?: () => void;
  wordmarkRef?: React.Ref<HTMLSpanElement>;
};

const FOOT: { id: FooterItemId; label: string; href: string; admin?: boolean }[] = [
  { id: "profiles", label: "Profiles", href: "/profiles/manage" },
  { id: "settings", label: "Settings", href: "/settings" },
  { id: "status", label: "Status", href: "/admin/status", admin: true },
];

function Count({ n, spine }: { n?: number; spine: boolean }) {
  if (!n) return null;
  if (spine) return <span aria-hidden className="absolute top-2 right-3 size-1.5 bg-spot" />;
  return <span className="type-folio ml-auto text-ink-45">{n > 99 ? "99+" : n}</span>;
}

function Row({ item, lit, count, spine, onNavigate }: { item: { id: string; folio?: string; label: string; href: string; g?: string }; lit: boolean; count?: number; spine: boolean; onNavigate?: () => void }) {
  const link = (
    <CineLink href={item.href} nav="section" aria-current={lit ? "page" : undefined} aria-label={spine ? `${item.folio ?? ""} ${item.label}`.trim() : undefined}
      onClick={onNavigate} className="cine-side-item">
      {item.folio ? <span className="cine-folio type-folio w-6 shrink-0 text-center" style={spine ? { fontSize: 14 } : undefined}>{item.folio}</span> : <span className="cine-folio w-6 shrink-0" />}
      <span className="cine-side-label type-ui min-w-0 flex-1 truncate">{item.label}</span>
      <span className="cine-side-label"><Count n={count} spine={false} /></span>
      {spine ? <Count n={count} spine /> : null}
    </CineLink>
  );
  return spine ? <Tooltip label={item.label} shortcut={item.g ? `g ${item.g}` : undefined}>{link}</Tooltip> : link;
}

/** §7.15 Contents sidebar. Pure view: every state can be captured from fixture props. */
export function SidebarView({ spine, overlay = false, lit, counts, isAdmin, novelsEnabled, hidden, onToggle, onNavigate, wordmarkRef }: SidebarViewProps) {
  const items = NAV_ITEMS.filter((i) => !hidden.has(i.id));
  const issue = items.filter((i) => i.group === "issue");
  const back = items.filter((i) => i.group === "back");
  const foot = FOOT.filter((f) => !f.admin || isAdmin);
  const label = spine ? "Expand sidebar" : "Collapse sidebar";
  const section = (kicker: string, list: NavItem[]) => list.length ? (
    <div className="pt-4">
      <p className="cine-side-label type-kicker px-4 pb-1 text-ink-45" style={{ height: spine ? 0 : undefined, overflow: "hidden" }} aria-hidden={spine || undefined}>{kicker}</p>
      {list.map((i) => <Row key={i.id} item={i} lit={lit === i.id} count={counts[i.id]} spine={spine} onNavigate={onNavigate} />)}
    </div>
  ) : null;
  return (
    <nav aria-label="Contents" data-spine={spine} data-overlay={overlay || undefined} className="cine-sidebar">
      <div className="px-4 pt-4">
        <div className="flex h-8 items-center">
          {spine ? <Monogram size={32} /> : <span ref={wordmarkRef} data-sidebar-wordmark><Wordmark size={20} /></span>}
        </div>
        <div className="mt-2"><OxfordRule /></div>
      </div>
      {novelsEnabled ? (
        <div className="px-4 pt-3">
          {spine ? (
            <div className="flex flex-col items-center"><ContentModeToggle className="flex-col !gap-0 [&_span[aria-hidden]]:hidden" /></div>
          ) : <ContentModeToggle />}
        </div>
      ) : null}
      <div className="cine-side-list" role="presentation">
        {section("IN THIS ISSUE", issue)}
        {section("THE BACK PAGES", back)}
      </div>
      <div className="border-t border-rule-1 py-2">
        <div className="cine-side-foot-items">
          {foot.map((f) => <Row key={f.id} item={f} lit={lit === f.id} count={counts[f.id]} spine={spine} onNavigate={onNavigate} />)}
        </div>
        <div className="cine-side-dots justify-center">
          <Menu align="start" trigger={<button type="button" aria-label="More" className="inline-flex min-h-(--mm-hit-min) min-w-(--mm-hit-min) items-center justify-center text-ink-60 hover:text-ink-100"><Glyph name="dots-three" size={20} /></button>}
            items={foot.map((f) => ({ id: f.id, label: f.label, onSelect: () => { window.location.assign(f.href); } }))} />
        </div>
        <div className="flex px-4 pt-1" style={{ justifyContent: spine ? "center" : "flex-end" }}>
          <Tooltip label={label} shortcut="mod+b">
            <button type="button" aria-label={label} aria-expanded={!spine} onClick={onToggle} data-sidebar-toggle
              className="inline-flex min-h-(--mm-hit-min) min-w-(--mm-hit-min) items-center justify-center text-ink-60 hover:text-ink-100">
              <SidebarSimpleIcon aria-hidden size={24} weight="light" color="currentColor" />
            </button>
          </Tooltip>
        </div>
      </div>
    </nav>
  );
}

