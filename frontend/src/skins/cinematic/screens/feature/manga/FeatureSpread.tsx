"use client";

import Link from "next/link";
import { ViewTransition, useEffect, useState } from "react";
import { libraryCoverUrl, seriesCoverUrl } from "@/features/library/api";
import type { SourceSeriesSummary, SourceSummary } from "@/features/sources/types";
import { coverTransitionName } from "../cover-name";
import { Glyph } from "../Glyph";
import { FeatureOverflow } from "./FeatureOverflow";
import { FeatureBody } from "./FeatureBody";
import type { SeriesPage } from "../use-series-page";
import s from "../feature.module.css";
import t from "../type.module.css";

export interface Ambient {
  duo: string;
  tint: string;
  ink: string;
}

/** The series' issue colour, dissolving in from the fallback over 800 ms. */
export function useAmbient(ambient: Ambient | null | undefined) {
  const [on, setOn] = useState(false);
  useEffect(() => {
    const id = requestAnimationFrame(() => setOn(true));
    return () => cancelAnimationFrame(id);
  }, []);
  return on && ambient
    ? ({ "--amb-duo": ambient.duo, "--amb-tint": ambient.tint, "--amb-ink": ambient.ink } as React.CSSProperties)
    : undefined;
}

export function descriptors(genres: string[]): string {
  const out: string[] = [];
  if (genres.some((g) => /action|horror|thriller|martial|gore|violence/i.test(g))) out.push("Violence");
  if (genres.some((g) => /ecchi|smut|adult|mature|sex/i.test(g))) out.push("Sexual content");
  return out.length ? out.join(" · ") : "Mature themes";
}

/** §8.17 D1 + D7: the desktop / tablet spread and the phone hero. */
export function FeatureSpread({
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
    <section className={s.spread} style={style} aria-label="Series">
      <div className={s.wrap} style={{ position: "relative" }}>
        <div className={s.head}>
          <Link href={`/sources/${encodeURIComponent(page.sourceId)}`} className={`${s.crumb} ${t.nav}`}>
            ← {source?.name ?? "Source"}
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
      </div>
      {mature && page.online ? (
        <div className={s.rating} role="note" aria-label="Rated 18+">
          <span className={s.certificate}>
            <Glyph name="certificate" size={20} />
            <span className={t.kicker}>18+</span>
          </span>
          <span className={`${t.caption}`} style={{ color: "var(--mm-color-ink-60)", marginLeft: 8 }}>
            {descriptors(series.genres ?? [])}
          </span>
        </div>
      ) : null}
      <div className={s.spreadIn}>
        <div className={s.art} aria-hidden="false">
          <div className={s.artBleed} style={{ backgroundImage: `url(${cover})` }} />
          <div className={s.artDuo} />
          <ViewTransition name={coverTransitionName(page.sourceId, page.seriesKey)} share="mm-match-cut" default="none">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              className={s.artImg}
              data-mm-cover={coverTransitionName(page.sourceId, page.seriesKey)}
              src={cover}
              alt={`${series.title} cover`}
              onDoubleClick={onViewCover}
              onContextMenu={(e) => e.preventDefault()}
            />
          </ViewTransition>
          <div className={s.artGutter} />
          <div className={s.artGrain} />
          {total > 0 ? <div className={s.readRule} style={{ width: `${(page.readCount / total) * 100}%` }} /> : null}
        </div>
        <div className={`${s.wrap} ${s.grid}`}>
          <FeatureBody page={page} series={series} source={source} stale={stale} onSelect={onSelect} />
        </div>
      </div>
      <div className={s.spill} />
    </section>
  );
}
