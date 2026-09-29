"use client";
import type { CSSProperties } from "react";
import { useDelayedFlag } from "../motion";
import { Flicker } from "../motion-components";

const WIDTHS = [92, 78, 96, 64, 88];

/** §7.17 "galley proofs": a skeleton appears only after 120 ms of waiting; data dissolves over it in 160 ms. Never a shimmer gradient. */
export function useSkeleton(loading: boolean) { return useDelayedFlag(120, loading); }

const bar = "bg-galley";

/** A bar at 50 % of the line height, vertically centred, ragged widths from the seeded list. */
export function GalleyLine({ index = 0, lineHeight = 24, width }: { index?: number; lineHeight?: number; width?: number }) {
  return (
    <Flicker index={index}>
      <div aria-hidden className="flex items-center" style={{ height: lineHeight }}>
        <div className={bar} style={{ height: lineHeight / 2, width: `${width ?? WIDTHS[index % WIDTHS.length]}%` }} />
      </div>
    </Flicker>
  );
}

export function GalleyHeadline({ lineHeight = 36 }: { lineHeight?: number }) {
  return (
    <div aria-hidden className="flex flex-col">
      <GalleyLine index={0} lineHeight={lineHeight} width={60} />
      <GalleyLine index={1} lineHeight={lineHeight} width={35} />
    </div>
  );
}

/** paper.1 plate with the inner hairline and an optional title card (Bodoni Italic 14/16 ink.45, bottom-left, 8 px inset). */
export function GalleyPlate({ title, index = 0, className = "", style }: { title?: string; index?: number; className?: string; style?: CSSProperties }) {
  return (
    <Flicker index={index} className={`size-full ${className}`}>
      <div aria-hidden className="relative size-full bg-paper-1" data-stock="raised" style={{ boxShadow: "inset 0 0 0 1px var(--mm-color-hairline-art)", ...style }}>
        {title ? <span className="absolute bottom-2 left-2 text-ink-45" style={{ fontFamily: "var(--font-display)", fontStyle: "italic", fontSize: 14, lineHeight: "16px" }}>{title}</span> : null}
      </div>
    </Flicker>
  );
}

/** One bar at 40 % of the numeral size. */
export function GalleyNumeral({ size = 72 }: { size?: number }) {
  return <Flicker><div aria-hidden className="flex items-center" style={{ height: size }}><div className={bar} style={{ height: size * 0.4, width: size * 1.2 }} /></div></Flicker>;
}
