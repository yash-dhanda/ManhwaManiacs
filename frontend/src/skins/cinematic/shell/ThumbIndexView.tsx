"use client";
import { useRef, type PointerEvent } from "react";
import { Icon } from "../Icon";
import type { IconRole } from "../icons/roles.generated";
import { CineLink } from "./CineLink";
import type { Branch } from "./nav-map";

export const THUMB_TABS: { id: Branch; label: string; icon: IconRole; href: string }[] = [
  { id: "tonight", label: "TONIGHT", icon: "home", href: "/" },
  { id: "library", label: "LIBRARY", icon: "library", href: "/library" },
  { id: "discover", label: "DISCOVER", icon: "discover", href: "/search" },
  { id: "downloads", label: "DOWNLOADS", icon: "downloads", href: "/downloads" },
  { id: "index", label: "INDEX", icon: "index", href: "/more" },
];

export type ThumbIndexViewProps = {
  active: Branch | null;
  badges?: Partial<Record<Branch, number>>;
  /** Tapping a tab: `index` is the tab; the container decides scroll-top, root and search-focus. */
  onTab?: (id: Branch, e: React.MouseEvent) => void;
  onLongPress?: (id: Branch) => void;
};

/** §7.14 thumb index: a flat black bar with a rule, never a floating pill. */
export function ThumbIndexView({ active, badges = {}, onTab, onLongPress }: ThumbIndexViewProps) {
  const idx = THUMB_TABS.findIndex((t) => t.id === active);
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const pressed = useRef(false);
  const down = (id: Branch) => (e: PointerEvent) => {
    if (e.pointerType === "mouse" && e.button !== 0) return;
    pressed.current = false;
    if (!onLongPress) return;
    timer.current = setTimeout(() => { pressed.current = true; onLongPress(id); }, 450);
  };
  const clear = () => { if (timer.current) { clearTimeout(timer.current); timer.current = null; } };
  return (
    <nav aria-label="Sections" className="cine-thumb cine-phone-only">
      <ul className="relative grid h-14 grid-cols-5">
        {idx >= 0 ? (
          <li aria-hidden className="cine-thumb-notch list-none" style={{ width: "20%", height: 2, transform: `translateX(${idx * 100}%)`, background: "transparent" }} data-notch={THUMB_TABS[idx].id}>
            <span className="mx-auto block h-0.5 w-6 bg-spot" />
          </li>
        ) : null}
        {THUMB_TABS.map((t) => {
          const on = t.id === active;
          const n = badges[t.id];
          return (
            <li key={t.id} className="list-none">
              <CineLink href={t.href} nav="section" aria-current={on ? "page" : undefined} data-tab={t.id}
                onClick={(e) => { if (pressed.current) { e.preventDefault(); pressed.current = false; return; } if (onTab) { onTab(t.id, e); } }}
                onPointerDown={down(t.id)} onPointerUp={clear} onPointerLeave={clear} onPointerCancel={clear}
                className={`cine-press flex h-14 min-w-(--mm-hit-min) flex-col items-center justify-center gap-0.5 ${on ? "text-ink-100" : "text-ink-60"}`}>
                <span className="relative inline-flex">
                  <Icon name={t.icon} size={24} filled={on} />
                  {n ? <span aria-hidden className="type-micro absolute -top-1 left-full -ml-2 min-h-4 min-w-4 bg-spot px-1 text-center font-folio text-paper-0">{n > 99 ? "99+" : n}</span> : null}
                </span>
                <span className="type-nav cine-thumb-label" style={{ fontVariationSettings: '"wdth" 62, "wght" 600' }}>{t.label}</span>
                {n ? <span className="sr-only">{`${n} new`}</span> : null}
              </CineLink>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}
