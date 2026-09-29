"use client";

import { useState, type ReactNode } from "react";
import { createPortal } from "react-dom";
import { AnchoredMenu, type MenuEntry } from "./Menu";
import { useGlassHost } from "./overlay-utils";
import type { ContextPreview } from "./useContextPreview";

/**
 * A context menu. With `preview` (the long-press lift) it puts `dimContext` (rgba(0,0,0,0.55) + backdrop blur 12) behind the lifted
 * object and blooms from its nearest edge. Without one, right-click on desktop opens the same menu at the pointer, no lift.
 */
export function ContextMenu({ items, label, preview, "data-testid": tid }: { items: MenuEntry[]; label: string; preview: ContextPreview; "data-testid"?: string }) {
  const host = useGlassHost();
  return (
    <>
      {preview.open && host ? createPortal(<div className="g-ctx-dim" onPointerDown={preview.hide} aria-hidden="true" />, host) : null}
      <AnchoredMenu items={items} label={label} open={preview.open} onOpenChange={(o) => { if (!o) preview.hide(); }} anchor={preview.element} data-testid={tid} />
    </>
  );
}

/** Right-click (and the context-menu key) anywhere inside opens the menu at the pointer. */
export function ContextMenuArea({ items, label, children, className, "data-testid": tid }: { items: MenuEntry[]; label: string; children: ReactNode; className?: string; "data-testid"?: string }) {
  const [at, setAt] = useState<{ x: number; y: number } | null>(null);
  const [open, setOpen] = useState(false);
  return (
    <div className={className} data-testid={tid} onContextMenu={(e) => { e.preventDefault(); setAt({ x: e.clientX, y: e.clientY }); setOpen(true); }}>
      {children}
      <AnchoredMenu items={items} label={label} open={open} onOpenChange={setOpen} anchor={at} />
    </div>
  );
}
