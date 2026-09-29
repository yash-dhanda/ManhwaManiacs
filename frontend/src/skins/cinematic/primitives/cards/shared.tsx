"use client";
import type { ReactNode } from "react";

/** A card that opens something: a link when `href`, else a button. The whole card is one focus target with the double ring. */
export function CardRoot({ href, onOpen, label, children, className = "", ...rest }: { href?: string; onOpen?: () => void; label: string; children: ReactNode; className?: string; "data-gallery"?: string }) {
  const cls = `cine-poster cine-press group relative block w-full text-left active:translate-y-px ${className}`;
  return href
    ? <a href={href} aria-label={label} data-gallery={rest["data-gallery"]} onClick={onOpen} className={cls}>{children}</a>
    : <button type="button" aria-label={label} data-gallery={rest["data-gallery"]} onClick={onOpen} className={cls}>{children}</button>;
}

/** Image frame: overflow hidden so the zoom stays inside; `cine-zoom` scales on card hover. */
export function Frame({ ratio, children, className = "" }: { ratio: string; children: ReactNode; className?: string }) {
  return <div className={`relative w-full overflow-hidden bg-paper-1 ${className}`} style={{ aspectRatio: ratio }}>{children}</div>;
}
