"use client";
import type { ReactNode } from "react";
import { Icon } from "../Icon";
import { FolioFlip } from "../primitives/FolioFlip";
import { IconButton } from "../primitives/IconButton";
import { Keycap } from "../primitives/Keycap";
import { CineLink } from "./CineLink";
import type { RunningHeadTrailing } from "./running-head-context";

export type OfflineBadge = "none" | "edition" | "glyph" | "back-online";
export type Crumb = { folio?: string; section: string; sectionHref?: string; tail?: string };

export type RunningHeadViewProps = {
  crumb: Crumb;
  /** Phone running title (`LIBRARY · UPDATES`). */
  title?: string;
  back?: { href?: string; label?: string } | true;
  onBack?: () => void;
  trailing?: RunningHeadTrailing[];
  contentModeChip?: ReactNode;
  /** The bar sits over art: transparent with the head scrim until it is solid. */
  overArt?: boolean;
  solid: boolean;
  /** Phone: the page masthead scrolled under the bar, so the title cross-fades in. */
  titleVisible: boolean;
  unread: number;
  offline: OfflineBadge;
  account: ReactNode;
  onSearch: () => void;
  onOfflineGlyph?: () => void;
  onBell?: () => void;
};

const badgeText = (o: OfflineBadge) => (o === "back-online" ? "BACK ONLINE" : "OFFLINE EDITION");

/** §7.13: desktop 56 px and phone 44 px running heads on one tree; media queries pick. */
export function RunningHeadView(p: RunningHeadViewProps) {
  const art = Boolean(p.overArt);
  const transparent = art && !p.solid;
  return (
    <header className="cine-head" data-solid={art ? p.solid : true} data-scrolled={p.solid} data-over-art={art || undefined} style={{ isolation: "isolate" }}>
      {/* Desktop frame */}
      <div className={`cine-desktop-only cine-inset relative h-14 items-center gap-6 ${transparent ? "before:scrim-head [--scrim-fade:64px]" : ""}`}>
        <nav aria-label="Breadcrumb" className="flex min-w-0 items-center gap-2">
          <span className="type-folio text-ink-45">{p.crumb.folio ? <>No. <FolioFlip value={p.crumb.folio} label={p.crumb.folio} className="" /> ·</> : null}</span>
          {p.crumb.sectionHref ? <CineLink href={p.crumb.sectionHref} nav="section" className="cine-crumb-link type-nav text-ink-60">{p.crumb.section}</CineLink> : <span className="type-nav text-ink-60">{p.crumb.section}</span>}
          {p.crumb.tail ? <><span aria-hidden className="type-nav text-ink-30">/</span><span className="type-nav min-w-0 truncate text-ink-100" aria-current="page">{p.crumb.tail}</span></> : null}
        </nav>
        {p.offline !== "none" ? <span className="type-micro border border-ink-45 bg-paper-0 px-1.5 py-0.5 text-ink-60" role="status">{badgeText(p.offline)}</span> : null}
        <div className="ml-auto flex items-center gap-4">
          <button type="button" onClick={p.onSearch} aria-label="Search or jump" aria-haspopup="dialog" data-search-trigger
            className="type-ui flex h-9 w-70 items-center gap-2 border-b border-rule-2 px-1 text-left text-ink-45 hover:text-ink-100">
            <Icon name="search" size={20} className="text-ink-60" />
            <span className="min-w-0 flex-1 truncate">Search or jump…</span>
            <Keycap combo="mod+k" />
          </button>
          <span className="relative">
            <IconButton variant="badged" icon="updates" label={p.unread ? `Updates, ${p.unread} unread` : "Updates"} badge={p.unread} onClick={p.onBell} />
            <span aria-live="polite" className="sr-only">{p.unread ? `${p.unread} unread updates` : "No unread updates"}</span>
          </span>
          {p.account}
        </div>
      </div>
      {/* Phone frame */}
      <div className={`cine-phone-only cine-inset relative ${transparent ? "before:scrim-head [--scrim-fade:44px]" : ""}`} style={{ paddingTop: "env(safe-area-inset-top)" }}>
        <div className="grid min-h-11 grid-cols-[1fr_auto_1fr] items-center py-0.5">
          <div className="flex items-center justify-start">
            {p.back ? (
              typeof p.back === "object" && p.back.href
                ? <CineLink href={p.back.href} nav="back" aria-label={p.back.label ?? "Back"} className="inline-flex min-h-(--mm-hit-min) min-w-(--mm-hit-min) items-center justify-center text-ink-100"><Icon name="back" size={24} /></CineLink>
                : <IconButton icon="back" label={typeof p.back === "object" && p.back.label ? p.back.label : "Back"} onClick={p.onBack} />
            ) : null}
          </div>
          <p className="cine-head-title type-nav max-w-[60vw] truncate text-center text-ink-60" style={{ opacity: p.titleVisible ? 1 : 0 }} aria-hidden={!p.titleVisible}>{p.title}</p>
          <div className="flex items-center justify-end">
            {p.contentModeChip}
            {p.trailing?.slice(0, 2).map((t, i) => t.href
              ? <CineLink key={i} href={t.href} aria-label={t.label} className="inline-flex min-h-(--mm-hit-min) min-w-(--mm-hit-min) items-center justify-center text-ink-60"><Icon name={t.icon} size={24} /></CineLink>
              : <IconButton key={i} icon={t.icon} label={t.label} onClick={t.onPress} />)}
            {p.offline === "glyph" ? <button type="button" aria-label="Offline edition, what this means" onClick={p.onOfflineGlyph} className="inline-flex min-h-(--mm-hit-min) min-w-(--mm-hit-min) items-center justify-center text-ink-60"><Icon name="offline" size={20} /></button> : null}
          </div>
        </div>
        {p.offline === "edition" || p.offline === "back-online" ? (
          <div className="pointer-events-none absolute inset-x-0 flex justify-center" style={{ top: "calc(env(safe-area-inset-top) + 34px)" }}>
            <span className="type-micro border border-ink-45 bg-paper-0 px-1.5 py-0.5 text-ink-60" role="status">{badgeText(p.offline)}</span>
          </div>
        ) : null}
      </div>
    </header>
  );
}
