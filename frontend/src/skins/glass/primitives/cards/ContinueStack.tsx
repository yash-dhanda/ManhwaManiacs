"use client";

import type { KeyboardEvent } from "react";
import { Button } from "../Button";
import { Cover } from "../Cover";
import { IconButton } from "../IconButton";
import { Progress } from "../Progress";
import { CardBase } from "./CardBase";
import type { PressState } from "../usePress";

export interface ContinueStackProps {
  title: string;
  cover: string;
  nextThumb?: string;
  chapter: number;
  page: number;
  pageCount: number;
  onContinue: () => void;
  /** the recap itself is web/41 */
  onPreviouslyOn?: () => void;
  onMore?: () => void;
  loading?: boolean;
  forceState?: PressState;
}

/**
 * 280 x 132 (phones) or 320 x 148 (desktop): the cover 88 x 132 on the left; behind it the next page's thumbnail peeks 8 px right and 6 px down,
 * rotated 2 deg, like a deck. An unopened next chapter (`pageCount == 0`) reads "Up next · Ch 143", shows only the ring's track and says "Start".
 */
export function ContinueStack({ title, cover, nextThumb, chapter, page, pageCount, onContinue, onPreviouslyOn, onMore, loading, forceState }: ContinueStackProps) {
  const fresh = pageCount === 0;
  const onKey = (e: KeyboardEvent<HTMLElement>) => { if (e.key === "p" && onPreviouslyOn) { e.preventDefault(); onPreviouslyOn(); } };
  if (loading) return <div className="g-card g-continue" data-slab="slab" aria-busy="true"><span className="g-skel" style={{ width: 88, height: "100%" , borderRadius: 14 }} /></div>;
  return (
    <CardBase label={`${title}, ${fresh ? `up next, chapter ${chapter}` : `chapter ${chapter}, page ${page} of ${pageCount}`}`} onPress={onContinue} className="g-continue" onKeyDown={onKey} forceState={forceState}>
      <div className="g-continue__deck" aria-hidden="true">
        {nextThumb ? <Cover className="g-continue__next" src={nextThumb} /> : <span className="g-continue__next" />}
        <Cover className="g-continue__cover" src={cover} />
      </div>
      <div className="g-continue__text">
        <h4 className="g-continue__title type-headline">{title}</h4>
        <p className="g-continue__meta type-footnote">{fresh ? `Up next · Ch ${chapter}` : `Ch ${chapter} · p. ${page} of ${pageCount}`}</p>
        <div className="g-continue__row">
          <Progress kind="ring" size={24} value={fresh ? 0 : page / pageCount} label={`Chapter ${chapter} progress`}>
            <span className="g-continue__num type-mono" aria-hidden="true">{chapter}</span>
          </Progress>
          <Button variant="plain" size="M" label={fresh ? "Start" : "Continue"} onPress={onContinue} />
        </div>
      </div>
      {onMore ? <span className="g-continue__more"><IconButton variant="plain" icon="dots-three" label={`More for ${title}`} onPress={onMore} /></span> : null}
    </CardBase>
  );
}
