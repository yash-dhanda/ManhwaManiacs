"use client";

import Link from "next/link";
import { useState } from "react";
import { estimateSeriesLength, formatEstimatedTotal, formatEstimatedWords, byline } from "@/features/novels/book";
import { useCachedNovelWordCounts } from "@/features/novels/hooks";
import { coverPath, shelfBlurb, shelfGenres } from "@/features/novels/shelf";
import { seriesCoverUrl, libraryCoverUrl } from "@/features/library/api";
import type { SourceSeriesSummary, SourceSummary } from "@/features/sources/types";
import { ViewTransition } from "react";
import { coverTransitionName } from "../cover-name";
import { Glyph } from "../Glyph";
import { SetHeading } from "../SetHeading";
import { FeatureOverflow } from "../manga/FeatureOverflow";
import { useAmbient, type Ambient } from "../manga/FeatureSpread";
import { useReaderEntry } from "../reader-entry";
import type { SeriesPage } from "../use-series-page";
import s from "../feature.module.css";
import t from "../type.module.css";

/** §8.18 E1: typographic front matter and the cover plate. */
export function BookFrontMatter({
  page,
  series,
  source,
  ambient,
  listenHref,
  narrationUnavailable,
  onViewCover,
  onAddToShelf,
  onTags,
  onMove,
  onPick,
}: {
  page: SeriesPage;
  series: SourceSeriesSummary;
  source: SourceSummary | undefined;
  ambient: Ambient | null | undefined;
  listenHref: string | null;
  narrationUnavailable: boolean;
  onViewCover: () => void;
  onAddToShelf: () => void;
  onTags: () => void;
  onMove: () => void;
  onPick: () => void;
}) {
  const enter = useReaderEntry();
  const style = useAmbient(ambient);
  const [more, setMore] = useState(false);
  const words = useCachedNovelWordCounts(page.ref);
  const est = estimateSeriesLength(series.chapter_count || page.chapters.length, words.values());
  const followed = page.followedId !== null;
  const cp = page.continueTo;
  const point = cp && cp.kind !== "caught-up" ? cp.point : null;
  const row = point ? page.rows.find((r) => r.id === point.chapterKey) : null;
  const raw = coverPath(series.cover_url);
  const cover = raw ? (page.follow?.cover_url ? libraryCoverUrl(page.follow.cover_url, "336px") : seriesCoverUrl(page.ref, "336px")) : null;
  const blurb = shelfBlurb(series.description);
  const unsaved = page.picker.unsaved.length;
  const facts = [
    `CHAPTERS ${(series.chapter_count || page.chapters.length).toLocaleString()}`,
    formatEstimatedWords(est)?.toUpperCase(),
    formatEstimatedTotal(est)?.toUpperCase(),
    series.status?.toUpperCase(),
  ].filter(Boolean);
  const by = byline(series.author);

  return (
    <section className={s.spread} style={style}>
      <div className={s.wrap}>
        <div className={s.head}>
          <Link href={`/sources/${encodeURIComponent(page.sourceId)}`} className={`${s.crumb} ${t.nav}`}>← {source?.name ?? "Source"}</Link>
          <FeatureOverflow page={page} seriesUrl={(series as unknown as { url?: string | null }).url ?? null} onViewCover={onViewCover} onAddToShelf={onAddToShelf} onTags={onTags} onMove={onMove} />
        </div>
        <div className={`${s.grid} ${s.book}`}>
          <div className={s.bookText}>
            <div className={`${t.kicker} ${s.kicker}`}>
              {["NOVEL", series.status?.toUpperCase(), (source?.name ?? page.sourceId).toUpperCase()].filter(Boolean).join(" · ")}
              {!page.online ? <span className={`${t.folio} ${s.badgeLine}`}>OFFLINE EDITION</span> : null}
            </div>
            <SetHeading text={series.title} masthead />
            {by ? <p className={s.byline}>{by}</p> : null}
            <div className={s.rule56} aria-hidden="true" />
            <div className={`${t.folio} ${s.set}`} style={{ color: "var(--mm-color-ink-80)" }}>{facts.join(" · ")}</div>
            {est.sampleSize > 0 && est.totalWords != null ? (
              <p className={`${t.caption} ${s.note}`}>Length estimated from {est.sampleSize} chapters read so far.</p>
            ) : null}
            {blurb ? (
              <p className={`${s.body} ${blurb.length >= 80 ? s.dropcap : ""} ${more ? "" : s.blurbClamp}`} style={{ marginTop: 20, maxWidth: "62ch" }}>{blurb}</p>
            ) : null}
            {blurb && blurb.length > 200 && !more ? (
              <button type="button" className={`${s.quiet} ${s.moreOnPhone}`} onClick={() => setMore(true)}>More</button>
            ) : null}
            {shelfGenres(series.genres).length > 0 ? (
              <div className={`${s.slug} ${t.kicker}`} style={{ marginTop: 16 }}>
                {shelfGenres(series.genres).map((g) => (
                  <Link key={g} href={`/sources/${encodeURIComponent(page.sourceId)}?genre=${encodeURIComponent(g)}`}>{g}</Link>
                ))}
              </div>
            ) : null}
            <div className={s.actions}>
              {cp?.kind === "caught-up" ? (
                <button type="button" className={`${s.btn} ${s.primary}`} disabled><span><Glyph name="check" /> All caught up</span></button>
              ) : page.primaryHref ? (
                <Link className={`${s.btn} ${s.primary}`} href={page.primaryHref} onClick={(e) => { e.preventDefault(); enter(page.primaryHref!); }}>
                  <span>{cp?.kind === "resume" ? "Continue" : "Start reading"}</span>
                  <span className={t.folio}>
                    {cp?.kind === "resume" && point && row
                      ? `CH ${row.ordinal ?? "·"} · ${row.pages > 0 ? Math.round((point.page / row.pages) * 100) : point.page}%`
                      : "CH 1"}
                  </span>
                </Link>
              ) : (
                <button type="button" className={`${s.btn} ${s.primary}`} disabled><span>Start reading</span></button>
              )}
              {listenHref ? (
                <Link className={`${s.btn} ${s.secondary}`} href={listenHref} onClick={(e) => { e.preventDefault(); enter(listenHref); }}>
                  <Glyph name="headphones" /> Listen
                </Link>
              ) : null}
            </div>
            {narrationUnavailable ? <p className={`${t.caption} ${s.note}`}>Narration isn&apos;t available for this book.</p> : null}
            <div className={s.iconRow} style={{ marginTop: 8 }}>
              <div>
                <button type="button" className={s.icon} aria-label={followed ? "In your library" : "Add to library"} title={followed ? "In your library" : "Add to library"} aria-pressed={followed} disabled={page.followBusy || !page.online} onClick={() => void page.toggleFollow()}>
                  <Glyph name={followed ? "check" : "plus"} />
                </button>
                <span className={s.lbl}>LIBRARY</span>
              </div>
              {unsaved > 0 && !page.picker.downloads.running ? (
                <div>
                  <button type="button" className={s.icon} aria-label={`Download book, ${unsaved} chapters`} title="Download book" disabled={page.picker.downloads.scope === null} onClick={() => page.picker.startKeys(page.picker.unsaved)}>
                    <Glyph name="download" />
                  </button>
                  <span className={s.lbl}>DOWNLOAD</span>
                </div>
              ) : null}
              <div>
                <button type="button" className={s.icon} aria-label="Pick chapters" title="Pick chapters" onClick={onPick}>
                  <Glyph name="scroll" />
                </button>
                <span className={s.lbl}>PICK</span>
              </div>
            </div>
          </div>
          <div className={s.bookArt}>
            {cover ? <div className={s.artBleed} style={{ backgroundImage: `url(${cover})` }} /> : null}
            <div className={s.artDuo} />
            <div className={s.artGrain} />
            {cover ? (
              <ViewTransition name={coverTransitionName(page.sourceId, page.seriesKey)} share="mm-match-cut" default="none">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img className={s.plate} data-mm-cover={coverTransitionName(page.sourceId, page.seriesKey)} src={cover} alt={`${series.title} cover`} onDoubleClick={onViewCover} onContextMenu={(e) => e.preventDefault()} />
              </ViewTransition>
            ) : (
              <div className={s.plate} aria-hidden="true" />
            )}
          </div>
        </div>
      </div>
    </section>
  );
}
