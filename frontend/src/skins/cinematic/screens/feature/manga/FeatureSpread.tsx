"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { libraryCoverUrl, seriesCoverUrl } from "@/features/library/api";
import type { SourceSeriesSummary, SourceSummary } from "@/features/sources/types";
import { chapterDateLabel } from "@/features/sources/chapter-date";
import { Glyph } from "../Glyph";
import { healthOf, HealthMark } from "../health";
import { SetHeading } from "../SetHeading";
import { FeatureOverflow } from "./FeatureOverflow";
import { useReaderEntry } from "../reader-entry";
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

function descriptors(genres: string[]): string {
  const out: string[] = [];
  if (genres.some((g) => /action|horror|thriller|martial|gore|violence/i.test(g))) out.push("Violence");
  if (genres.some((g) => /ecchi|smut|adult|mature|sex/i.test(g))) out.push("Sexual content");
  return out.length ? out.join(" · ") : "Mature themes";
}

const upper = (v: string | null | undefined) => v?.replace(/[_-]/g, " ").toUpperCase() ?? null;

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
  const enter = useReaderEntry();
  const style = useAmbient(ambient);
  const followed = page.followedId !== null;
  const cover = page.follow?.cover_url ? libraryCoverUrl(page.follow.cover_url, "720px") : seriesCoverUrl(page.ref, "720px");
  const latest = page.chapters.reduce<string | null>((acc, c) => (c.release_date && (!acc || c.release_date > acc) ? c.release_date : acc), null);
  const updated = chapterDateLabel(latest)?.toUpperCase();
  const cp = page.continueTo;
  const total = page.chapters.length;
  const mature = page.follow?.rating === "mature";
  const need = page.online ? undefined : "Needs a connection.";
  const point = cp && cp.kind !== "caught-up" ? cp.point : null;
  const pointRow = point ? page.rows.find((r) => r.id === point.chapterKey) : null;
  const folio = pointRow?.ordinal ? `CH ${pointRow.ordinal}` : "CH 1";

  const primary =
    cp?.kind === "caught-up" ? (
      <button type="button" className={`${s.btn} ${s.primary}`} disabled aria-label="All caught up">
        <span><Glyph name="check" /> All caught up</span>
      </button>
    ) : page.primaryHref ? (
      <Link
        className={`${s.btn} ${s.primary}`}
        href={page.primaryHref}
        onClick={(e) => {
          e.preventDefault();
          enter(page.primaryHref!);
        }}
      >
        <span>{cp?.kind === "resume" ? "Continue" : "Read"}</span>
        <span className={t.folio}>{folio}{cp?.kind === "resume" && point && point.page > 1 ? ` · p.${point.page}` : ""}</span>
      </Link>
    ) : (
      <button type="button" className={`${s.btn} ${s.primary}`} disabled><span>Read</span></button>
    );

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
            <svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="10" fill="none" stroke="currentColor" strokeWidth="1.5" /></svg>
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
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            className={s.artImg}
            src={cover}
            alt={`${series.title} cover`}
            onDoubleClick={onViewCover}
            onContextMenu={(e) => e.preventDefault()}
            style={{ viewTransitionName: `cover-${page.sourceId}-${page.seriesKey}`.replace(/[^a-zA-Z0-9_-]/g, "_") }}
          />
          <div className={s.artGutter} />
          <div className={s.artGrain} />
          {total > 0 ? <div className={s.readRule} style={{ width: `${(page.readCount / total) * 100}%` }} /> : null}
        </div>
        <div className={`${s.wrap} ${s.grid}`}>
          <div className={s.spreadText}>
            <div className={`${t.kicker} ${s.kicker}`}>
              {["MANHWA", upper(series.status), total ? `${total} CHAPTERS` : null].filter(Boolean).join(" · ")}
              {stale ? <span className={`${t.folio} ${s.badgeLine}`}>SAVED COPY</span> : null}
              {!page.online ? <span className={`${t.folio} ${s.badgeLine}`}>OFFLINE EDITION</span> : null}
            </div>
            <SetHeading text={series.title} />
            {series.description ? <p className={`${t.deck} ${s.deck}`}>{series.description.split(/(?<=[.!?])\s/)[0]}</p> : null}
            <dl className={`${s.credits} ${t.credit}`}>
              {series.author ? (<><dt className={t.kicker}>STORY</dt><dd className={s.set}>{series.author}</dd></>) : null}
              {series.artist ? (<><dt className={t.kicker}>ART</dt><dd className={s.set}>{series.artist}</dd></>) : null}
              <dt className={t.kicker}>SOURCE</dt>
              <dd className={s.set}>{source?.name ?? page.sourceId} <HealthMark health={healthOf(source)} /></dd>
              {series.status ? (<><dt className={t.kicker}>STATUS</dt><dd className={s.set}>{upper(series.status)}</dd></>) : null}
              {updated ? (<><dt className={t.kicker}>UPDATED</dt><dd className={s.set}>{updated}</dd></>) : null}
            </dl>
            <div className={s.actions}>
              {primary}
              {page.readAll ? (
                <Link className={`${s.btn} ${s.secondary}`} href={page.readAll} title="Every chapter in one continuous scroll" onClick={(e) => { e.preventDefault(); enter(page.readAll!); }}>
                  <Glyph name="scroll" /> Read all
                </Link>
              ) : null}
            </div>
            <div className={s.iconRow} style={{ marginTop: 8 }}>
              <div>
                <button type="button" className={s.icon} aria-label={followed ? "Following" : "Follow"} title={followed ? "Following" : "Follow"} aria-pressed={followed} disabled={page.followBusy || !page.online} onClick={() => void page.toggleFollow()}>
                  <Glyph name={followed ? "check" : "plus"} />
                </button>
                <span className={s.lbl}>FOLLOW</span>
              </div>
              {followed ? (
                <div>
                  <button type="button" className={s.icon} aria-label="Favourite" title="Favourite" aria-pressed={Boolean(page.follow?.is_favorite)} disabled={!page.online} onClick={() => page.patch({ is_favorite: !page.follow?.is_favorite })}>
                    <Glyph name="star" fill={Boolean(page.follow?.is_favorite)} />
                  </button>
                  <span className={s.lbl}>FAVOURITE</span>
                </div>
              ) : null}
              {followed ? (
                <div>
                  <button type="button" className={s.icon} aria-label="Notify" title="Notify" aria-pressed={Boolean(page.follow?.notify)} disabled={!page.online} onClick={() => page.patch({ notify: !page.follow?.notify })}>
                    <Glyph name="bell" fill={Boolean(page.follow?.notify)} />
                  </button>
                  <span className={s.lbl}>NOTIFY</span>
                </div>
              ) : null}
              <div>
                <button type="button" className={s.icon} aria-label="Download" title="Download" onClick={onSelect}>
                  <Glyph name="download" />
                </button>
                <span className={s.lbl}>DOWNLOAD</span>
              </div>
            </div>
            {page.followError && (page.followError as { code?: string }).code === "follow_limit_reached" ? (
              <p className={`${t.caption} ${s.err}`}>You&apos;re following 1,000 series, the limit for a profile.</p>
            ) : null}
            {need ? <p className={`${t.caption} ${s.note}`}>{need}</p> : null}
          </div>
        </div>
      </div>
      <div className={s.spill} />
    </section>
  );
}
