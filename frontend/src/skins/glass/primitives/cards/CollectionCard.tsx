"use client";

import { CardBase } from "./CardBase";

const ROT = [-8, -3, 3, 8];

/** A 21:9 slab: a fanned stack of up to four member covers (72 x 108, rotated -8, -3, 3, 8 deg, overlapping 40 %), the name `title3` and "12 series". `fanOpen` spreads the fan (the zoom into the collection, web/32). */
export function CollectionCard({ name, count, covers, onOpen, fanOpen }: { name: string; count: number; covers: readonly string[]; onOpen: () => void; fanOpen?: boolean }) {
  const c = covers.slice(0, 4);
  return (
    <CardBase label={`${name}, ${count} series`} onPress={onOpen} className="g-collection">
      <div className="g-collection__fan" data-open={fanOpen ? "" : undefined} aria-hidden="true">
        {c.map((src, i) => <img key={i} src={src} alt="" draggable={false} style={{ ["--rot" as string]: `${ROT[i + (4 - c.length) / 2 | 0] ?? 0}deg`, ["--i" as string]: i }} />)}
      </div>
      <div className="g-collection__text"><h4 className="type-title3">{name}</h4><p className="type-footnote">{count} series</p></div>
    </CardBase>
  );
}
