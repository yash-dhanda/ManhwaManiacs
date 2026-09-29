"use client";

import { Poster, type PosterProps } from "../Poster";

/** Grids: a Poster + 8 px + title `footnote` 13/600 in 2 lines + meta `caption1` `label3` in 1 line. No slab: the poster is the card. */
export function SeriesCard({ meta, ...poster }: PosterProps & { meta?: string }) {
  return (
    <div className="g-seriescard" role="listitem">
      <Poster {...poster} width={undefined} />
      <p className="g-seriescard__title type-footnote">{poster.title}</p>
      {meta ? <p className="g-seriescard__meta type-caption1">{meta}</p> : null}
    </div>
  );
}
