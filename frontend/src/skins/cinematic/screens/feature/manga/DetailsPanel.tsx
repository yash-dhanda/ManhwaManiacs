"use client";

import Link from "next/link";
import type { SourceSeriesSummary } from "@/features/sources/types";
import type { SeriesPage } from "../use-series-page";
import { healthOf, HealthMark } from "../health";
import { useSources } from "@/features/sources/hooks";
import s from "../feature.module.css";
import t from "../type.module.css";

/** §8.17 D4: synopsis with the drop cap, genres, enriched credits, source credit. */
export function DetailsPanel({ page, series }: { page: SeriesPage; series: SourceSeriesSummary }) {
  const sources = useSources().data;
  const source = sources?.find((x) => x.id === page.sourceId);
  const text = series.description?.trim() ?? "";
  const alt = (series as unknown as { alt_titles?: string[] }).alt_titles ?? [];
  const url = (series as unknown as { url?: string | null }).url ?? null;
  const en = page.enrichment;
  return (
    <div className={s.details}>
      {text ? (
        <p className={`${s.body} ${text.length >= 80 ? s.dropcap : ""}`}>
          {text}
        </p>
      ) : (
        <p className={s.body}>No synopsis yet.</p>
      )}
      {alt.length > 0 ? (
        <p className={t.caption} style={{ color: "var(--mm-color-ink-60)", marginTop: 24 }}>
          {alt.join(" · ")}
        </p>
      ) : null}
      {series.genres.length > 0 ? (
        <div className={`${s.slug} ${t.kicker}`} style={{ marginTop: 24 }}>
          {series.genres.map((g) => (
            <Link key={g} href={`/sources/${encodeURIComponent(page.sourceId)}?genre=${encodeURIComponent(g)}`}>{g}</Link>
          ))}
        </div>
      ) : null}
      <dl className={`${s.credits} ${t.credit}`}>
        {en?.format ? (<><dt className={t.kicker}>FORMAT</dt><dd>{en.format}</dd></>) : null}
        {en?.score != null ? (<><dt className={t.kicker}>ANILIST</dt><dd>★ {en.score}</dd></>) : null}
        {en?.official?.length ? (
          <>
            <dt className={t.kicker}>READ</dt>
            <dd style={{ flexWrap: "wrap" }}>
              {en.official.map((o) => (
                <a key={o.url} className={s.link} href={o.url} target="_blank" rel="noreferrer noopener">Read on {o.site} ↗</a>
              ))}
            </dd>
          </>
        ) : null}
        <dt className={t.kicker}>SOURCE</dt>
        <dd>{source?.name ?? page.sourceId} <HealthMark health={healthOf(source)} /></dd>
      </dl>
      {url ? (
        <p style={{ marginTop: 16 }}>
          <a className={s.link} href={url} target="_blank" rel="noreferrer noopener">Open on {source?.name ?? page.sourceId} ↗</a>
        </p>
      ) : null}
    </div>
  );
}
