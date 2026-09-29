"use client";

import { Poster, type PosterProps } from "../Poster";
import { Badge } from "../Badge";

/** Search: 112 wide x 208: a 112 x 168 poster + title in 2 lines `footnote`; the source glyph badge is hidden inside source groups (`hideSource`). */
export function ResultCard({ source, hideSource, ...poster }: PosterProps & { source?: string; hideSource?: boolean }) {
  return (
    <div className="g-resultcard" role="listitem">
      <Poster {...poster} width={112} />
      <p className="g-seriescard__title type-footnote">{poster.title}</p>
      {source && !hideSource ? <span className="g-resultcard__src"><Badge kind="source" name={source} /></span> : null}
    </div>
  );
}
