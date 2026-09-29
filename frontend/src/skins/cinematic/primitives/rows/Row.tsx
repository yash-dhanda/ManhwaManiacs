"use client";
import { useState, type ReactNode } from "react";
import { haptic } from "../../haptics";
import { Icon } from "../../Icon";
import type { IconRole } from "../../icons/roles.generated";
import { Checkbox } from "../Checkbox";
import { Glyph } from "../glyphs";
import { useLongPress } from "../hooks";
import { IconButton } from "../IconButton";
import { ContextMenu } from "../ContextMenu";
import { Menu } from "../Menu";
import { GalleyLine } from "../Skeleton";
import { useCoarsePointer, useDesktopFrame } from "../overlay-hooks";
import type { MenuItemDef } from "../menu-types";

export type RowState = {
  selected?: boolean;
  /** Select mode: a leading 20 px checkbox. */
  selectMode?: boolean;
  onSelectedChange?: (next: boolean) => void;
  disabled?: boolean;
  loading?: boolean;
  /** Reason in words; the caption turns proof and a Retry appears. */
  error?: string;
  onRetry?: () => void;
  /** Novel TOC current chapter or a go-to target. */
  current?: boolean;
};

export type RowProps = RowState & {
  title: ReactNode;
  caption?: ReactNode;
  /** Leading 20 Regular icon, a 40 x 60 cover node, or a 32 avatar node. */
  leadingIcon?: IconRole;
  leading?: ReactNode;
  trailing?: ReactNode;
  chevron?: boolean;
  /** Row menu items: trailing dots-three, right-click on desktop, 450 ms long-press on touch. */
  menu?: MenuItemDef[];
  /** Reorder handle etc. after the menu button. */
  end?: ReactNode;
  onClick?: () => void;
  min?: number;
  className?: string;
  "data-gallery"?: string;
};

/** The frame every row type shares: dividers, hover bar, pressed fill, selected, current, loading, error, disabled, row menus. */
export function RowFrame({ children, min = 56, menu, selected, selectMode, onSelectedChange, disabled, loading, error, onRetry, current, onClick, end, className = "", ...rest }: {
  children: ReactNode; min?: number; menu?: MenuItemDef[]; end?: ReactNode; onClick?: () => void; className?: string; "data-gallery"?: string;
} & RowState) {
  const desktop = useDesktopFrame();
  const coarse = useCoarsePointer();
  const [open, setOpen] = useState(false);
  const lp = useLongPress(menu && coarse && !desktop ? () => { haptic("longpress.open"); setOpen(true); } : undefined);
  const body = (
    <div
      {...(coarse && !desktop ? { onPointerDown: lp.onPointerDown } : {})}
      data-stock={selected ? "raised" : current ? "wash" : undefined}
      aria-current={current ? "location" : undefined} aria-busy={loading || undefined} data-gallery={rest["data-gallery"]}
      className={`group/row relative flex w-full items-center gap-3 border-b border-rule-1 px-4 transition-colors duration-(--mm-dur-snap) active:bg-paper-3 active:duration-(--mm-dur-tick) ${
        selected ? "bg-paper-3" : current ? "bg-spot-wash cine-fadein" : "hover:text-ink-100"} ${disabled ? "text-ink-30" : "text-ink-100"} ${className}`}
      style={{ minHeight: min }}
    >
      <span aria-hidden className={`absolute inset-y-0 left-0 w-0.5 ${selected || current ? "bg-spot" : disabled ? "hidden" : "bg-ink-100 opacity-0 transition-opacity duration-(--mm-dur-snap) group-hover/row:opacity-100"}`} />
      {selectMode ? <Checkbox checked={!!selected} onCheckedChange={(v) => onSelectedChange?.(v)} label="Select row" hideLabel /> : null}
      <div className="flex min-w-0 flex-1 items-center gap-3">
        {loading ? <div className="flex w-full flex-col justify-center gap-2 py-3" aria-hidden><GalleyLine width={200} /><GalleyLine width={120} lineHeight={16} /></div> : children}
      </div>
      {error && onRetry ? <button type="button" onClick={onRetry} className="type-label min-h-(--mm-hit-min) px-2 text-ink-60 hover:underline hover:underline-offset-4">Retry</button> : null}
      {menu && menu.length && !selectMode && !loading ? <Menu open={open} onOpenChange={setOpen} trigger={<IconButton label="More actions" icon="overflow" />} items={menu} /> : null}
      {end}
    </div>
  );
  const clickable = onClick && !disabled && !loading;
  const row = clickable ? (
    <div role="button" tabIndex={0} aria-disabled={disabled || undefined} data-clickable
      onClick={() => { if (selectMode) onSelectedChange?.(!selected); else onClick?.(); }}
      onKeyDown={(e) => { if (e.target === e.currentTarget && (e.key === "Enter" || e.key === " ")) { e.preventDefault(); if (selectMode) onSelectedChange?.(!selected); else onClick?.(); } }}
      className="block w-full outline-offset-[-2px]">{body}</div>
  ) : body;
  return menu && menu.length && desktop ? <ContextMenu items={menu}>{row}</ContextMenu> : row;
}

/** Standard row: leading icon / cover / avatar, title + caption, trailing folio value or chevron (56 one line, 72 two). */
export function Row({ title, caption, leadingIcon, leading, trailing, chevron, error, min, ...p }: RowProps) {
  const two = !!caption || !!error;
  return (
    <RowFrame {...p} error={error} min={min ?? (two ? 72 : 56)}>
      {leadingIcon ? <Icon name={leadingIcon} size={20} className="shrink-0 text-ink-60" /> : leading}
      <div className="min-w-0 flex-1 py-2">
        <p className="type-title truncate">{title}</p>
        {error ? <p className="type-caption text-proof">{error}</p> : caption ? <p className="type-caption text-ink-45">{caption}</p> : null}
      </div>
      {trailing ? <span className="type-folio shrink-0 text-ink-60">{trailing}</span> : null}
      {chevron ? <Glyph name="caret-right" size={20} className="shrink-0 text-ink-45" /> : null}
    </RowFrame>
  );
}
