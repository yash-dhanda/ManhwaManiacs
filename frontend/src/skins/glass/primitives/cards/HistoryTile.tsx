"use client";

import { Poster } from "../Poster";

/** A poster with a 3 px progress line along its bottom edge; a 36 px play orb bottom-right ("p. 18" or "42 %") drawn as a content twin on the cover-overlay backing; the title and "Ch 12 · 3 h ago" below. */
export function HistoryTile({ title, src, progress, orbText, meta, onOpen }: { title: string; src: string; progress: number; orbText: string; meta: string; onOpen: () => void }) {
  return (
    <div className="g-historytile" role="listitem">
      <div className="g-historytile__poster">
        <Poster title={`${title}, ${orbText}`} src={src} onOpen={onOpen} progress={progress} />
        <span className="g-historytile__orb" aria-hidden="true"><span className="g-historytile__t type-caption2">{orbText}</span></span>
      </div>
      <p className="type-footnote g-seriescard__title">{title}</p>
      <p className="type-caption1 g-seriescard__meta">{meta}</p>
    </div>
  );
}
