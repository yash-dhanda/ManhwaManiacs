"use client";

import Link from "next/link";
import type { SourceSeriesSummary, SourceSummary } from "@/features/sources/types";
import { chapterDateLabel } from "@/features/sources/chapter-date";
import { Glyph } from "../Glyph";
import { healthOf, HealthMark } from "../health";
import { SetHeading } from "../SetHeading";
import { useReaderEntry } from "../reader-entry";
import type { SeriesPage } from "../use-series-page";
import s from "../feature.module.css";
import t from "../type.module.css";

const upper = (v: string | null | undefined) => v?.replace(/[_-]/g, " ").toUpperCase() ?? null;


/** Kicker, title, deck, credits and actions: the text of the desktop spread and of the phone hero (§8.17 D1, D7). */
export function FeatureBody({
  page,
  series,
  source,
  stale,
  onSelect,
}: {
  page: SeriesPage;
  series: SourceSeriesSummary;
  source: SourceSummary | undefined;
  stale: boolean;
  onSelect: () => void;
}) {
  const enter = useReaderEntry();
  const followed = page.followedId !== null;
  const latest = page.chapters.reduce<string | null>((acc, c) => (c.release_date && (!acc || c.release_date > acc) ? c.release_date : acc), null);
  const updated = chapterDateLabel(latest)?.toUpperCase();
  const cp = page.continueTo;
  const total = page.chapters.length;
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
  );
}
