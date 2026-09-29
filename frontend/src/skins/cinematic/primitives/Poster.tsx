"use client";
import { useRef, useState, type MouseEvent, type ReactNode } from "react";
import { cn } from "@/lib/cn";
import { folioLabel } from "../a11y/folio";
import { BadgeStack } from "./Badge";
import { CineImage, type MatchCut } from "./CineImage";
import { Glyph } from "./glyphs";
import { useLongPress, useRootScale } from "./hooks";
import { IconButton } from "./IconButton";
import { PosterProgress } from "./Progress";
import { GalleyPlate } from "./Skeleton";

export type PosterProps = {
  title: string;
  src?: string | null;
  href?: string;
  onOpen?: (e: MouseEvent) => void;
  /** wall: no caption; below: title + folio caption; ranked: numeral behind the left edge. */
  caption?: "wall" | "below" | "ranked";
  rank?: number;
  /** Folio caption, e.g. `CH 142 · 3 NEW`, `NOT STARTED`, `CAUGHT UP`, `CH 12 OF 40`. */
  folio?: string;
  badges?: ReactNode;
  progress?: number;
  favourite?: boolean;
  selectMode?: boolean;
  selected?: boolean;
  onSelect?: () => void;
  disabled?: boolean;
  loading?: boolean;
  /** Desktop Library hover icons. */
  hoverIcons?: { favourite: boolean; notify: boolean; onFavourite: () => void; onNotify: () => void };
  manualOrder?: boolean;
  matchCut?: MatchCut;
  onQuickLook?: () => void;
  /** Long-press on a broken cover offers "Retry cover". */
  onRetryCover?: () => void;
  /** Called with the poster rect after a 600 ms pointer dwell (opens the rail slate). */
  onDwell?: (rect: DOMRect) => void;
  onLeave?: () => void;
  ambientDuo?: string;
  className?: string;
  tabIndex?: number;
  "aria-expanded"?: boolean;
  "aria-controls"?: string;
  "data-gallery"?: string;
  posterRef?: (el: HTMLElement | null) => void;
};

/** §7.7 poster: 2:3, radius 0, paper.1 placeholder, inner hairline. Corners: badges TL, select TR, hover icons BR, drag handle BL. */
export function Poster(p: PosterProps) {
  const { title, caption = "below", folio, selectMode, selected, disabled, loading, favourite } = p;
  const scale = useRootScale();
  const dwell = useRef<ReturnType<typeof setTimeout>>(undefined);
  const face = useRef<HTMLElement>(null);
  const [broken, setBroken] = useState(false);
  const [retryOpen, setRetryOpen] = useState(false);
  const [attempt, setAttempt] = useState(0);
  const press = useLongPress(broken ? () => setRetryOpen(true) : p.onQuickLook);
  const folioText = disabled ? "UNAVAILABLE" : folio;
  const name = [caption === "ranked" && p.rank ? `Number ${p.rank}, ${title}` : title, favourite ? "Favourite" : null, selected ? "Selected" : null, disabled ? "Unavailable" : null].filter(Boolean).join(", ");
  const Face = (p.href && !disabled ? "a" : "button") as "a";
  const ambient = p.ambientDuo ? ({ ["--amb-duo" as string]: p.ambientDuo } as React.CSSProperties) : undefined;
  return (
    <div className={cn("cine-poster group/poster relative flex flex-col", p.className)} style={{ ...ambient, containerType: "inline-size" }} data-gallery={p["data-gallery"]}
      onPointerEnter={(e) => { if (e.pointerType !== "mouse" || !p.onDwell) return; dwell.current = setTimeout(() => face.current && p.onDwell?.(face.current.getBoundingClientRect()), 600); }}
      onPointerLeave={() => { clearTimeout(dwell.current); p.onLeave?.(); }}>
      {caption === "ranked" && p.rank ? (
        <span aria-hidden className="pointer-events-none absolute bottom-0 select-none text-ink-45" style={{ left: 0, transform: "translateX(-50%)", fontFamily: "var(--font-display)", fontWeight: 400, fontStyle: "normal", fontSize: "150cqw", lineHeight: 1, zIndex: 0 }}>{p.rank}</span>
      ) : null}
      <Face ref={(el: HTMLElement | null) => { face.current = el; p.posterRef?.(el); }} {...(p.href && !disabled ? { href: p.href } : { type: "button" as const })} aria-label={name}
        aria-disabled={disabled || undefined} aria-busy={loading || undefined} tabIndex={p.tabIndex} aria-expanded={p["aria-expanded"]} aria-controls={p["aria-controls"]}
        onClick={(e: MouseEvent) => { if (disabled) { e.preventDefault(); return; } p.onOpen?.(e); }} {...press}
        className={cn("cine-poster-face cine-press relative cine-z1 block aspect-[2/3] w-full", disabled && "opacity-40")} style={{ cursor: disabled ? "default" : "pointer", ...(selected ? { filter: "brightness(0.7)" } : {}) }}>
        {loading ? <GalleyPlate title={title} /> : <CineImage key={attempt} src={p.src} alt="" title={title} matchCut={p.matchCut} onFail={() => setBroken(true)} />}
        {p.badges ? <BadgeStack className="absolute top-1 left-1">{p.badges}</BadgeStack> : null}
        {p.progress != null ? <PosterProgress value={p.progress} /> : null}
        {selected ? <span aria-hidden className="pointer-events-none absolute inset-0" style={{ boxShadow: "inset 0 0 0 2px var(--mm-color-spot)" }} /> : null}
      </Face>
      {retryOpen && broken ? (
        <button type="button" className="type-label absolute inset-x-1 bottom-1 cine-z2 min-h-(--mm-hit-min) bg-ink-100 text-paper-0" onClick={() => { setRetryOpen(false); setBroken(false); setAttempt((a) => a + 1); p.onRetryCover?.(); }}>Retry cover</button>
      ) : null}
      {selectMode || p.hoverIcons ? (
        <button type="button" aria-label={selected ? `Deselect ${title}` : `Select ${title}`} aria-pressed={!!selected} onClick={p.onSelect}
          className={cn("absolute top-0 right-0 cine-z2 inline-flex min-h-(--mm-hit-min) min-w-(--mm-hit-min) items-center justify-center", !selectMode && "opacity-0 group-hover/poster:opacity-100 group-focus-within/poster:opacity-100")}>
          <span className={cn("inline-flex size-6 items-center justify-center border border-ink-100 bg-onart text-paper-0", selected && "bg-ink-100")}>{selected ? <Glyph name="check" size={16} /> : null}</span>
        </button>
      ) : null}
      {p.hoverIcons && !selectMode ? (
        <div className="absolute right-1 bottom-1 cine-z2 flex gap-2 opacity-0 group-hover/poster:opacity-100 group-focus-within/poster:opacity-100" style={caption === "below" ? { bottom: `calc(${caption === "below" ? "3.4em" : "0"} + 4px)` } : undefined}>
          <IconButton variant="on-art" icon="notify" label={p.hoverIcons.notify ? "Stop notifying" : "Notify me"} selected={p.hoverIcons.notify} onClick={p.hoverIcons.onNotify} />
          <IconButton variant="on-art" icon="favourite" label={p.hoverIcons.favourite ? "Unfavourite" : "Favourite"} selected={p.hoverIcons.favourite} onClick={p.hoverIcons.onFavourite} />
        </div>
      ) : null}
      {p.manualOrder ? (
        <span aria-label="Drag to reorder" role="img" className="absolute bottom-1 left-1 cine-z2 inline-flex size-10 items-center justify-center bg-onart text-ink-100 opacity-0 group-hover/poster:opacity-100"><Glyph name="dots-six-vertical" size={20} /></span>
      ) : null}
      {caption === "below" ? (
        <div className="relative cine-z1 mt-2 flex flex-col gap-1">
          <p className={cn("type-title text-ink-100", scale >= 1.3 ? "line-clamp-2" : "truncate")}>{title}</p>
          {folioText ? <p className="type-folio flex items-center gap-1 text-ink-45" aria-label={folioLabel(folioText)}>{favourite ? <span className="text-spot"><Glyph name="star" size={12 as never} filled /></span> : null}<span aria-hidden>{folioText}</span></p> : null}
        </div>
      ) : null}
    </div>
  );
}
