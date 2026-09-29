"use client";

import { Badge } from "../Badge";
import { Button } from "../Button";
import { Chip } from "../Chip";
import { Cover } from "../Cover";
import { Icon } from "../Icon";
import { CardBase } from "./CardBase";

export interface WorldCardProps {
  title: string;
  cover: string;
  kind: string;
  status: string;
  chapters: number;
  rating: number;
  tags?: readonly string[];
  /** the `why` line, after the machine sparkle */
  why?: string;
  /** available: the whole card opens the series, with a source chip; info-only: dashed, two plain buttons */
  variant: "available" | "info";
  source?: string;
  moreSources?: number;
  site?: string;
  onOpen?: () => void;
  onSearchMine?: () => void;
  onReadOn?: () => void;
  loading?: boolean;
}

/** 300 x 132: cover 80 x 120, title `headline` in 2 lines, "Manhwa · Ongoing" `caption1`, "120 ch · ★ 8.4" `mono`, up to 3 tags, the `why` line `footnote` italic. */
export function WorldCard({ title, cover, kind, status, chapters, rating, tags = [], why, variant, source, moreSources, site, onOpen, onSearchMine, onReadOn, loading }: WorldCardProps) {
  if (loading) return <div className="g-card g-world" data-slab="slab" aria-busy="true"><span className="g-skel" style={{ width: 80, height: 120, borderRadius: 14 }} /></div>;
  const info = variant === "info";
  const body = (
    <>
      <Cover className="g-world__cover" src={cover} />
      <div className="g-world__text">
        <h4 className="g-world__title type-headline">{title}</h4>
        <p className="type-caption1 g-world__sub">{kind} · {status}</p>
        <p className="type-mono g-world__num">{chapters} ch · ★ {rating.toFixed(1)}</p>
        <div className="g-world__tags">{tags.slice(0, 3).map((t) => <Chip key={t} kind="tag" label={t} />)}</div>
        {why ? <p className="g-world__why type-footnote"><Icon name="sparkle" size={14} color="var(--mm-color-machine)" /> <em>{why}</em></p> : null}
        {!info && source ? <span className="g-world__src"><Badge kind="source" name={`On ${source}`} />{moreSources ? <span className="type-caption1"> +{moreSources}</span> : null}</span> : null}
        {info ? (
          <div className="g-world__info"><p className="type-caption1">Not on your sources</p><span><Button variant="plain" size="S" label="Search my sources" onPress={() => onSearchMine?.()} /><Button variant="plain" size="S" label={`Read on ${site ?? "the web"}`} icon="arrow-square-out" onPress={() => onReadOn?.()} /></span></div>
        ) : null}
      </div>
    </>
  );
  return info ? (
    <div className="g-card g-world" data-slab="slab" data-info="" role="group" aria-label={`${title}, not on your sources`}><div className="g-card__body">{body}</div></div>
  ) : (
    <CardBase label={`${title}, ${kind}, ${status}${source ? `, on ${source}` : ""}`} onPress={onOpen} className="g-world">{body}</CardBase>
  );
}
