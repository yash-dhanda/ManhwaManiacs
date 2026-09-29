"use client";

import Link from "next/link";
import { ViewTransition } from "react";
import { libraryCoverUrl, seriesCoverUrl } from "@/features/library/api";
import type { SourceSeriesSummary, SourceSummary } from "@/features/sources/types";
import { coverTransitionName } from "../cover-name";
import { Glyph } from "../Glyph";
import type { SeriesPage } from "../use-series-page";
import { FeatureBody } from "./FeatureBody";
import { FeatureOverflow } from "./FeatureOverflow";
import { descriptors, useAmbient, type Ambient } from "./FeatureSpread";
import s from "../feature.module.css";
import t from "../type.module.css";

/** §8.17 D7: the phone hero. A full-bleed 4:5 cover, on-art running head, the title block over its lower quarter. */
export function FeaturePhoneHero({
  page,
  series,
  source,
  ambient,
  stale,
  onViewCover,
  onAddToShelf,
  onTags,
  onMove,
  onSelect,
}: {
  page: SeriesPage;
  series: SourceSeriesSummary;
  source: SourceSummary | undefined;
  ambient: Ambient | null | undefined;
  stale: boolean;
  onViewCover: () => void;
  onAddToShelf: () => void;
  onTags: () => void;
  onMove: () => void;
  onSelect: () => void;
}) {
  const style = useAmbient(ambient);
  const cover = page.follow?.cover_url ? libraryCoverUrl(page.follow.cover_url, "720px") : seriesCoverUrl(page.ref, "720px");
  const total = page.chapters.length;
  const mature = page.follow?.rating === "mature";
  return (
    <section className={s.spread} style={style} aria-label="Series" data-phone-hero="">
      <div className={s.phoneArt}>
        <ViewTransition name={coverTransitionName(page.sourceId, page.seriesKey)} share="mm-match-cut" default="none">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            className={s.phoneImg}
            src={cover}
            alt={`${series.title} cover`}
            onContextMenu={(e) => e.preventDefault()}
            onTouchStart={(e) => {
              const id = window.setTimeout(onViewCover, 450);
              const cancel = () => window.clearTimeout(id);
              e.currentTarget.addEventListener("touchend", cancel, { once: true });
              e.currentTarget.addEventListener("touchmove", cancel, { once: true });
            }}
          />
        </ViewTransition>
        <div className={s.phoneScrim} />
        <div className={s.artGrain} />
        {total > 0 ? <div className={s.readRule} style={{ width: `${(page.readCount / total) * 100}%` }} /> : null}
        <div className={s.phoneHead}>
          <Link href={`/sources/${encodeURIComponent(page.sourceId)}`} className={`${s.icon} ${s.onArt}`} aria-label={`Back to ${source?.name ?? "the source"}`}>
            <Glyph name="back" />
          </Link>
          <FeatureOverflow
            page={page}
            seriesUrl={(series as unknown as { url?: string | null }).url ?? null}
            onViewCover={onViewCover}
            onAddToShelf={onAddToShelf}
            onTags={onTags}
            onMove={onMove}
          />
        </div>
        {mature && page.online ? (
          <div className={s.rating} role="note" aria-label="Rated 18+">
            <span className={s.certificate}>
              <Glyph name="certificate" size={20} />
              <span className={t.kicker}>18+</span>
            </span>
            <span className={t.caption} style={{ color: "var(--mm-color-ink-60)", marginLeft: 8 }}>{descriptors(series.genres ?? [])}</span>
          </div>
        ) : null}
      </div>
      <div className={`${s.wrap} ${s.phoneText}`}>
        <FeatureBody page={page} series={series} source={source} stale={stale} onSelect={onSelect} />
      </div>
      <div className={s.spill} />
    </section>
  );
}
