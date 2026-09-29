"use client";
import { animate } from "motion/react";
import { useEffect, useRef, useState, type ReactNode } from "react";
import { haptic } from "../haptics";
import { readReduced } from "../motion";
import { durMs, ease } from "../tokens.generated";
import { CineImage } from "./CineImage";
import { ContextMenu } from "./ContextMenu";
import { useLongPress } from "./hooks";
import { useCoarsePointer, useDesktopFrame } from "./overlay-hooks";
import { Sheet } from "./Sheet";
import type { MenuItemDef } from "./menu-types";

export type QuickLookInfo = { title: string; kicker?: string; credits?: string; src: string };

/** Phone quick look: a Sheet whose header cover is FLIPped from the poster's rect (480 ms ease.turn, during the Rise). */
export function QuickLook({ open, onOpenChange, info, from, items }: { open: boolean; onOpenChange: (o: boolean) => void; info: QuickLookInfo; from: DOMRect | null; items: MenuItemDef[] }) {
  const cover = useRef<HTMLDivElement>(null);
  const [fade, setFade] = useState(false);
  useEffect(() => {
    if (!open) return;
    const el = cover.current;
    if (!el) return;
    if (readReduced()) { setFade(true); return; } // eslint-disable-line react-hooks/set-state-in-effect -- reduced: cover fades in, no FLIP
    if (!from) return;
    const to = el.getBoundingClientRect();
    animate(el, { x: [from.left - to.left, 0], y: [from.top - to.top, 0], scaleX: [from.width / to.width, 1], scaleY: [from.height / to.height, 1] },
      { duration: durMs.spread / 1000, ease: ease.turn as unknown as [number, number, number, number] });
  }, [open, from]);
  return (
    <Sheet open={open} onOpenChange={onOpenChange} title={info.title} kicker={info.kicker ?? "QUICK LOOK"}
      headerLead={<div ref={cover} data-fade={fade || undefined} className="relative h-36 w-24 shrink-0 origin-top-left overflow-hidden data-[fade]:cine-fadein-fast"><CineImage src={info.src} alt="" /></div>}>
      {info.credits ? <p className="type-credit mb-3 text-ink-60">{info.credits}</p> : null}
      <div role="menu" aria-label="Actions" onClickCapture={(e) => { if ((e.target as HTMLElement).closest("[role=menuitem]")) onOpenChange(false); }}>
        <PlainItems items={items} />
      </div>
    </Sheet>
  );
}

/** Action list inside the sheet: the same rows as the menu, as plain buttons (no menu popup). */
function PlainItems({ items }: { items: MenuItemDef[] }) {
  return (
    <ul className="-mx-5">
      {items.map((it) => (
        <li key={it.id} className={it.separatorBefore ? "border-t border-rule-1" : ""}>
          <button type="button" role="menuitem" aria-disabled={it.disabled || undefined} title={it.disabledReason}
            onClick={() => { if (!it.disabled) it.onSelect?.(); }}
            className={`type-ui flex min-h-12 w-full items-center px-5 text-left active:bg-paper-3 ${it.disabled ? "text-ink-30" : it.destructive ? "text-proof" : "text-ink-100"}`}>{it.label}</button>
        </li>
      ))}
    </ul>
  );
}

/**
 * Wrap a poster, cutting or row that offers quick look. Phones: 450 ms long-press dims the target to 70 % for 120 ms then
 * opens the sheet (haptic longpress.open). Desktop: right-click opens the ContextMenu with the same actions.
 */
export function QuickLookTarget({ info, items, children, className = "" }: { info: QuickLookInfo; items: MenuItemDef[]; children: ReactNode; className?: string }) {
  const desktop = useDesktopFrame();
  const coarse = useCoarsePointer();
  const ref = useRef<HTMLDivElement>(null);
  const [open, setOpen] = useState(false);
  const [rect, setRect] = useState<DOMRect | null>(null);
  const [dim, setDim] = useState(false);
  const lp = useLongPress(() => {
    setDim(true); haptic("longpress.open");
    setRect(ref.current?.getBoundingClientRect() ?? null);
    setTimeout(() => { setDim(false); setOpen(true); }, durMs.snap);
  });
  if (desktop || !coarse) return <ContextMenu items={items} className={className}>{children}</ContextMenu>;
  return (
    <>
      <div ref={ref} {...lp} style={{ opacity: dim ? 0.7 : 1, transition: `opacity ${durMs.snap}ms linear`, WebkitTouchCallout: "none" }} className={`cine-press ${className}`}>{children}</div>
      <QuickLook open={open} onOpenChange={setOpen} info={info} from={rect} items={items} />
    </>
  );
}
