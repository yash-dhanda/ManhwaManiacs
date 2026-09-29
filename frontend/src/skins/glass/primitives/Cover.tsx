"use client";

import type { CSSProperties, SyntheticEvent } from "react";

/** A decorative cover or logo image (`alt=""`): the one place the skin uses a plain <img>, so Next's optimiser never sits between a cover and its palette. */
export function Cover({ src, className, style, width, height, onLoad, onError }: { src: string; className?: string; style?: CSSProperties; width?: number; height?: number; onLoad?: (e: SyntheticEvent<HTMLImageElement>) => void; onError?: (e: SyntheticEvent<HTMLImageElement>) => void }) {
  // eslint-disable-next-line @next/next/no-img-element
  return <img src={src} alt="" draggable={false} className={className} style={style} width={width} height={height} onLoad={onLoad} onError={onError} />;
}
