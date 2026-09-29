"use client";
import type { MouseEvent } from "react";
import { Icon } from "../Icon";
import type { IconRole } from "../icons/roles.generated";
import { useHold } from "./hooks";
import { LeaderDial } from "./Progress";
import { Tooltip } from "./Tooltip";

export type IconButtonVariant = "bare" | "on-art" | "ruled" | "badged";

/** §7.2. Every icon button requires `label` (aria-label and tooltip text). */
export function IconButton({ label, icon, variant = "bare", selected = false, loading = false, disabled = false, error, badge, shortcut, onClick, className = "", ...rest }: {
  label: string; icon: IconRole; variant?: IconButtonVariant; selected?: boolean; loading?: boolean; disabled?: boolean;
  /** Reason text: the glyph turns proof for 2000 ms and the tooltip gives the reason. */
  error?: string; badge?: number; shortcut?: string; onClick?: (e: MouseEvent<HTMLButtonElement>) => void; className?: string; "data-gallery"?: string;
}) {
  const errHeld = useHold(error, 2000);
  const size = variant === "on-art" || variant === "ruled" ? 20 : 24;
  const box = variant === "on-art" ? "size-10 bg-onart" : variant === "ruled" ? "size-9 border border-rule-2" : "size-9";
  const tone = disabled ? "text-ink-30" : errHeld ? "text-proof" : variant === "on-art" ? "text-ink-100" : selected ? "text-ink-100" : "text-ink-60";
  const btn = (
    <button type="button" aria-label={label} aria-pressed={selected || undefined} aria-busy={loading || undefined} aria-disabled={disabled || undefined}
      data-gallery={rest["data-gallery"]}
      onClick={(e) => { if (disabled || loading) { e.preventDefault(); return; } onClick?.(e); }}
      className={`group relative inline-flex min-h-(--mm-hit-min) min-w-(--mm-hit-min) items-center justify-center ${className}`}>
      <span className={`relative inline-flex items-center justify-center transition-colors duration-(--mm-dur-tick) ${box} ${tone} ${disabled ? "" : "group-hover:text-ink-100 group-hover:outline group-hover:outline-1 group-hover:-outline-offset-1 group-hover:outline-ink-30 group-active:bg-paper-3 group-active:translate-y-px"}`}>
        {loading ? <LeaderDial size={16} immediate /> : <Icon name={icon} size={size} filled={selected} />}
        {selected ? <span aria-hidden className="absolute inset-x-0 h-0.5 bg-spot" style={{ bottom: -6 }} /> : null}
        {variant === "badged" && badge ? <span aria-hidden className="type-micro absolute -top-1 -right-1 min-h-4 min-w-4 bg-spot px-1 text-center text-paper-0">{badge > 99 ? "99+" : badge}</span> : null}
      </span>
    </button>
  );
  return <Tooltip label={errHeld && error ? error : label} shortcut={shortcut}>{btn}</Tooltip>;
}
