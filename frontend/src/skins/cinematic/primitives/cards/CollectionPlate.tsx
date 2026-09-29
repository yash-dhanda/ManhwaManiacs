"use client";
import { useLayoutEffect, useRef, useState } from "react";
import { Avatar } from "../Avatar";
import { CineImage } from "../CineImage";
import { useDuotone } from "../../duotone";
import { CardRoot } from "./shared";

/** §7.6 collection plate: 16:9 mosaic of the first four member covers in duotone, name over scrim-foot, credit line, shared-with avatars. */
export function CollectionPlate({ name, covers, duo, credit, sharedWith = [], selected, href, onOpen, "data-gallery": g }: {
  name: string; covers: (string | null)[]; duo?: string; credit: string; sharedWith?: string[]; selected?: boolean; href?: string; onOpen?: () => void; "data-gallery"?: string;
}) {
  const filter = useDuotone(duo ?? "#B8B2A4");
  const text = useRef<HTMLDivElement>(null);
  const [solidAt, setSolidAt] = useState(48);
  useLayoutEffect(() => { if (text.current) setSolidAt(text.current.offsetHeight + 8); }, [name, credit]);
  return (
    <CardRoot href={href} onOpen={onOpen} label={`${name}. ${credit}`} data-gallery={g}>
      <div className="relative aspect-video w-full overflow-hidden bg-paper-1" style={{ ["--amb-tint" as string]: duo }}>
        <div className="grid size-full grid-cols-2 grid-rows-2" style={{ filter }}>
          {[0, 1, 2, 3].map((i) => <div key={i} className="relative overflow-hidden"><CineImage src={covers[i]} alt="" /></div>)}
        </div>
        <div aria-hidden className="scrim-foot pointer-events-none absolute inset-0" style={{ ["--scrim-solid-at" as string]: `${solidAt}px` }} />
        <div ref={text} className="absolute inset-x-3 bottom-3"><p className="type-subhead text-ink-100">{name}</p><p className="type-kicker mt-1 text-ink-60">{credit}</p></div>
        {sharedWith.length ? <div className="absolute right-3 bottom-3 flex -space-x-1">{sharedWith.slice(0, 3).map((k) => <Avatar key={k} presetKey={k} size={20} />)}</div> : null}
        {selected ? <span aria-hidden className="pointer-events-none absolute inset-0" style={{ boxShadow: "inset 0 0 0 2px var(--mm-color-spot)" }} /> : null}
      </div>
    </CardRoot>
  );
}
